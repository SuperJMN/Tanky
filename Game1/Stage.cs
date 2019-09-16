using System;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    internal class Stage : IStage
    {
        private readonly ContentManager content;
        private IDisposable enemyAdder;

        public Stage(ContentManager content, double width, double height)
        {
            this.content = content;
            
            enemyAdder = Observable.Interval(TimeSpan.FromSeconds(3)).Subscribe(_ => this.Add(new Ship()
            {
                Top = Utils.Random.Next((int) Constants.GroundTop),
                Left = width, 
            }));
        }

        public ICollection<IStageObject> Objects { get; } = new List<IStageObject>();

        public void AddRelative(IStageObject subject, IStageObject origin, RelativePosition relativePosition)
        {
            if (relativePosition == RelativePosition.Right)
            {
                subject.Left = origin.Left + origin.Width;
                subject.Top = origin.Top + (origin.Height - subject.Height)/2;
            }

            if (relativePosition == RelativePosition.Left)
            {
                subject.Left = origin.Left - origin.Width;
                subject.Top = origin.Top + (origin.Height - subject.Height)/2;
            }

            Add(subject);
        }

        public void Update(GameTime gameTime)
        {
            foreach (var stageObject in Objects.ToList())
            {
                stageObject.Update(gameTime);
            }
        }

        public void Remove(IStageObject stageObject)
        {
            Objects.Remove(stageObject);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (var stageObject in Objects)
            {
                stageObject.Draw(spriteBatch);
            }
        }

        public void Add(IStageObject stageObject)
        {
            stageObject.Stage = this;
            Objects.Add(stageObject);
            stageObject.LoadContent(content);
        }
    }
}