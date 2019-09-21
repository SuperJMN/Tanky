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
            ObjectRemoved(stageObject);
        }

        protected virtual void ObjectRemoved(IStageObject stageObject)
        {
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
            BeforeDraw(spriteBatch);

            foreach (var stageObject in objects.ToList())
            {
                stageObject.Draw(spriteBatch);
            }

            AfterDraw(spriteBatch);
        }

        protected virtual void BeforeDraw(SpriteBatch spriteBatch)
        {
        }

        protected virtual void AfterDraw(SpriteBatch spriteBatch)
        {
        }

        public void Add(IStageObject stageObject)
        {
            stageObject.Stage = this;
            stageObject.LoadContent(content);
            stageObject.Initialized();
            EnsurePositionAndSizeAreCorrect(stageObject);
            objects.Add(stageObject);

            ObjectAdded(stageObject);
        }

        protected virtual void ObjectAdded(IStageObject stageObject)
        {
        }

        private static void EnsurePositionAndSizeAreCorrect(IStageObject stageObject)
        {
            if (stageObject.Left == 0 && stageObject.Top == 0)
            {
                throw new ApplicationException("The position of the object has not been set");
            }

            if (stageObject.Width == 0 || stageObject.Height == 0)
            {
                throw new ApplicationException("The size of the object has not been set");
            }
        }
    }
}