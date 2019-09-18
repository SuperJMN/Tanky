using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace SuperJMN.MonoGame
{
    public class Stage : IStage
    {
        private readonly ContentManager content;

        private readonly List<IStageObject> objects = new List<IStageObject>();

        public Stage(ContentManager content, double width, double height)
        {
            Width = width;
            Height = height;
            this.content = content;
        }

        public double Width { get; }
        public double Height { get; }

        public IEnumerable<IStageObject> Objects => objects.AsReadOnly();

        public void AddRelative(IStageObject toAdd, IStageObject origin, RelativePosition relativePosition)
        {
            if (relativePosition == RelativePosition.Right)
            {
                toAdd.Left = origin.Left + origin.Width;
                toAdd.Top = origin.Top + (origin.Height - toAdd.Height) / 2;
            }

            if (relativePosition == RelativePosition.Left)
            {
                toAdd.Left = origin.Left - origin.Width;
                toAdd.Top = origin.Top + (origin.Height - toAdd.Height) / 2;
            }

            if (relativePosition == RelativePosition.Bottom)
            {
                toAdd.Left = origin.Left + (origin.Width - toAdd.Width) / 2;
                toAdd.Top = origin.Top + origin.Height;
            }

            if (relativePosition == RelativePosition.Center)
            {
                toAdd.Left = origin.Left + (origin.Width - toAdd.Width) / 2;
                toAdd.Top = origin.Top + origin.Height - toAdd.Height;
            }

            Add(toAdd);
        }

        public void Update(GameTime gameTime)
        {
            var objs = objects.ToList();

            foreach (var stageObject in objs.ToList())
            {
                stageObject.Update(gameTime);
            }

            foreach (var stageObject in objs)
            {
                var others = objs.Except(new[] {stageObject});
                foreach (var other in others)
                {
                    if (stageObject.Collides(other))
                    {
                        stageObject.CollideWith(other);
                        other.CollideWith(stageObject);
                    }
                }
            }
        }

        public void Remove(IStageObject stageObject)
        {
            objects.Remove(stageObject);
        }

        public virtual void Dispose()
        {
            foreach (var stageObject in objects.ToList())
            {
                if (stageObject is IDisposable d)
                {
                    d.Dispose();
                }
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (var stageObject in objects.ToList())
            {
                stageObject.Draw(spriteBatch);
            }
        }

        public void Add(IStageObject stageObject)
        {
            stageObject.Stage = this;
            objects.Add(stageObject);
            stageObject.LoadContent(content);
        }
    }
}